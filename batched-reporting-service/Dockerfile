# Using build arguments to specify the AWS account and region
ARG AWS_ACCOUNT
ARG AWS_REGION
ARG BUILD_IMAGE_TAG
ARG APP_IMAGE_TAG

#Build Runner Image
FROM --platform=$BUILDPLATFORM ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/dotnet/sdk:${BUILD_IMAGE_TAG} AS build

ARG TARGETARCH
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_SESSION_TOKEN

ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
    AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
    AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}

LABEL dev="reporting-base"
WORKDIR /src
COPY ["Batched.Reporting.Web/Batched.Reporting.Web.csproj", "Batched.Reporting.Web/"]
COPY ["Batched.Reporting.Contracts/Batched.Reporting.Contracts.csproj", "Batched.Reporting.Contracts/"] 
COPY ["Batched.Reporting.Core/Batched.Reporting.Core.csproj", "Batched.Reporting.Core/"]
COPY ["Batched.Reporting.Shared/Batched.Reporting.Shared.csproj", "Batched.Reporting.Shared/"]
COPY Nuget.Config Batched.Reporting.Web/Nuget.Config
RUN apt update
RUN aws codeartifact login --tool dotnet --repository nuget-repo --domain batched --domain-owner 061669522376 --region us-east-2
RUN dotnet restore "Batched.Reporting.Web/Batched.Reporting.Web.csproj" \
-s https://batched-061669522376.d.codeartifact.us-east-2.amazonaws.com/nuget/nuget-repo/v3/index.json \
-s https://api.nuget.org/v3/index.json
COPY . .
WORKDIR "/src/Batched.Reporting.Web"
RUN dotnet build "Batched.Reporting.Web.csproj" -c Release -o /app
RUN dotnet publish "Batched.Reporting.Web.csproj" -a $TARGETARCH -c Release -o /app/publish

#Final Runner Image
FROM --platform=$TARGETPLATFORM ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/dotnet/aspnet:${APP_IMAGE_TAG} AS final
LABEL dev="reporting-base"
WORKDIR /app
RUN sudo chown -R appuser:appgroup /app
COPY --from=build --chown=appuser:appgroup /app/publish .
USER appuser
EXPOSE 5000
ENTRYPOINT ["dotnet", "Batched.Reporting.Web.dll", "--urls", "http://0.0.0.0:5000" ]
