package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ssm"
)

const (
	extensionName = "parameter-store-extension"
)

var (
	extensionID string
	ssmClient   *ssm.Client
	httpClient  = &http.Client{Timeout: 0} // No timeout for event polling
)

// LambdaEvent represents the structure of Lambda extension events
type LambdaEvent struct {
	EventType          string `json:"eventType"`
	DeadlineMs         int64  `json:"deadlineMs"`
	RequestID          string `json:"requestId"`
	InvokedFunctionArn string `json:"invokedFunctionArn"`
	ShutdownReason     string `json:"shutdownReason,omitempty"`
}

// ExtensionRegistration represents the registration payload
type ExtensionRegistration struct {
	Events []string `json:"events"`
}

func main() {
	// Setup signal handling
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigCh
		log.Printf("[%s] Received signal. Exiting.", extensionName)
		cancel()
		os.Exit(0)
	}()

	// Initialize AWS SDK
	if err := initializeAWS(ctx); err != nil {
		log.Fatalf("[%s] Failed to initialize AWS SDK: %v", extensionName, err)
	}

	log.Printf("[%s] === INIT PHASE START ===", extensionName)

	// Register extension
	if err := registerExtension(); err != nil {
		log.Fatalf("[%s] Failed to register extension: %v", extensionName, err)
	}

	// Update configuration during INIT phase
	if err := updateAppSettings(ctx); err != nil {
		log.Printf("[%s] Failed to update config: %v", extensionName, err)
	}

	log.Printf("[%s] === INIT PHASE COMPLETE ===", extensionName)

	// Process events
	if err := processEvents(ctx); err != nil {
		log.Fatalf("[%s] Error processing events: %v", extensionName, err)
	}
}

func initializeAWS(ctx context.Context) error {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return fmt.Errorf("failed to load AWS config: %w", err)
	}

	ssmClient = ssm.NewFromConfig(cfg)
	return nil
}

func registerExtension() error {
	runtimeAPI := os.Getenv("AWS_LAMBDA_RUNTIME_API")
	if runtimeAPI == "" {
		return fmt.Errorf("AWS_LAMBDA_RUNTIME_API environment variable not set")
	}

	payload := ExtensionRegistration{
		Events: []string{"INVOKE", "SHUTDOWN"},
	}

	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal registration payload: %w", err)
	}

	url := fmt.Sprintf("http://%s/2020-01-01/extension/register", runtimeAPI)
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(payloadBytes))
	if err != nil {
		return fmt.Errorf("failed to create registration request: %w", err)
	}

	req.Header.Set("Lambda-Extension-Name", extensionName)
	req.Header.Set("Content-Type", "application/json")

	resp, err := httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to register extension: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("registration failed with status %d: %s", resp.StatusCode, string(body))
	}

	extensionID = resp.Header.Get("Lambda-Extension-Identifier")
	if extensionID == "" {
		return fmt.Errorf("no extension ID received in registration response")
	}

	log.Printf("[%s] Registered with ID: %s", extensionName, extensionID)
	return nil
}

func updateAppSettings(ctx context.Context) error {
	parameterName := os.Getenv("PARAMETER_NAME")
	configFile := os.Getenv("CONFIG_FILE")
	if configFile == "" {
		configFile = "/tmp/appsettings.json"
	}

	if parameterName == "" {
		log.Printf("[%s] No PARAMETER_NAME set, skipping config update", extensionName)
		return nil
	}

	log.Printf("[%s] Fetching parameter: %s", extensionName, parameterName)

	// Fetch parameter from Parameter Store
	input := &ssm.GetParameterInput{
		Name:           &parameterName,
		WithDecryption: &[]bool{true}[0],
	}

	result, err := ssmClient.GetParameter(ctx, input)
	if err != nil {
		return fmt.Errorf("failed to get parameter from SSM: %w", err)
	}

	if result.Parameter == nil || result.Parameter.Value == nil {
		return fmt.Errorf("parameter value is nil")
	}

	configData := *result.Parameter.Value

	// Ensure directory exists
	if err := os.MkdirAll(filepath.Dir(configFile), 0755); err != nil {
		return fmt.Errorf("failed to create directory for config file: %w", err)
	}

	// Write config data to file
	if err := os.WriteFile(configFile, []byte(configData), 0644); err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	log.Printf("[%s] ✅ Config updated successfully: %s", extensionName, configFile)
	return nil
}

func processEvents(ctx context.Context) error {
	runtimeAPI := os.Getenv("AWS_LAMBDA_RUNTIME_API")
	url := fmt.Sprintf("http://%s/2020-01-01/extension/event/next", runtimeAPI)

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
			// Continue to next event
		}

		req, err := http.NewRequest("GET", url, nil)
		if err != nil {
			return fmt.Errorf("failed to create event request: %w", err)
		}

		req.Header.Set("Lambda-Extension-Identifier", extensionID)

		resp, err := httpClient.Do(req)
		if err != nil {
			return fmt.Errorf("failed to get next event: %w", err)
		}

		if resp.StatusCode != http.StatusOK {
			resp.Body.Close()
			return fmt.Errorf("event request failed with status %d", resp.StatusCode)
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			return fmt.Errorf("failed to read event body: %w", err)
		}

		var event LambdaEvent
		if err := json.Unmarshal(body, &event); err != nil {
			return fmt.Errorf("failed to unmarshal event: %w", err)
		}

		if event.EventType == "SHUTDOWN" {
			log.Printf("[%s] Received SHUTDOWN event. Exiting.", extensionName)
			return nil
		}

		// Process other events if needed
		if err := executeCustomProcessing(&event); err != nil {
			log.Printf("[%s] Error processing event: %v", extensionName, err)
		}
	}
}

func executeCustomProcessing(event *LambdaEvent) error {
	// Process events - no heavy work here anymore
	// Config update already done in INIT phase
	return nil
}
