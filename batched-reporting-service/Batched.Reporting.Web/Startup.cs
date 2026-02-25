using Autofac;
using Autofac.Extensions.DependencyInjection;
using Batched.Common;
using Batched.Reporting.Shared;
using System.Text.Json.Serialization;
using Batched.Common.Auth;
using Batched.Reporting.Web.Middlewares;
using Microsoft.OpenApi.Models;
using System.Reflection;

namespace Batched.Reporting.Web
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }
        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();
            services.AddSingleton<BatchedAuthorizeAttribute>();

            services.AddHttpClient();
            services.RegisterLogDependencies();
            services.AddMvc()
                .AddJsonOptions(options =>
                    {
                        var serializationOptions = options.JsonSerializerOptions;
                        serializationOptions.PropertyNameCaseInsensitive = true;
                        serializationOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
                        serializationOptions.IgnoreNullValues = true;
                        serializationOptions.Converters.Add(new JsonStringEnumConverter());
                    })
                .AddControllersAsServices();

            services.Configure<SwaggerAuthOptions>(Configuration.GetSection("SwaggerAuthentication"));
            // Configure Swagger if enabled in app settings
            if (Configuration.GetValue<bool>("Swagger:Enabled"))
            {
                services.AddSwaggerGen(c =>
                {
                    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Reporting Service API", Version = "v1" });
                    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
                    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
                    c.IncludeXmlComments(xmlPath);
                    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                    {
                        In = ParameterLocation.Header,
                        Description = "Please enter a valid Auth token",
                        Name = "Authorization",
                        Type = SecuritySchemeType.Http,
                        BearerFormat = "JWT",
                        Scheme = "Bearer"
                    });
                    c.AddSecurityRequirement(new OpenApiSecurityRequirement
                    {
                        {
                            new OpenApiSecurityScheme
                            {
                                Reference = new OpenApiReference
                                {
                                    Type=ReferenceType.SecurityScheme,
                                    Id="Bearer"
                                }
                            },
                            Array.Empty<string>()
                        }
                    });
                    c.OperationFilter<AddRequiredHeaderParameter>();
                });
            }

            services.AddSingleton<IConfigProvider, AppSettingConfigProvider>();
            services.AddScoped<IWebClient, Batched.Common.WebClient>();

            /* JWT authentication setup*/
            AuthExtensions.SetupJWTAuthentication(services, Configuration.GetSection("AppSettings"));
        }


        public void ConfigureContainer(ContainerBuilder builder)
        {
            // Add any Autofac modules or registrations.
            // This is called AFTER ConfigureServices so things you
            // register here OVERRIDE things registered in ConfigureServices.
            //
            // You must have the call to AddAutofac in the Program.Main
            // method or this won't be called.
            builder.RegisterModule(new RegistryModule());
            builder.RegisterModule(new Core.RegistryModule(Configuration));
            builder.RegisterModule(new Data.RegistryModule());
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ILogWriterFactory logWriterFactory,
            IObjectProvider objectProvider)
        {
            app.UseMiddleware<ContextInjectorMiddleware>();
            app.UseMiddleware<LoggingMiddleware>();
            app.UseMiddleware<ExceptionMiddlerware>();

            app.UseRouting();
            app.UseCors(x => x
                 .AllowAnyOrigin()
                 .AllowAnyMethod()
                 .AllowAnyHeader());

            app.UseAuthentication();
            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });

            if (Configuration.GetValue<bool>("Swagger:Enabled"))
            {
                app.UseSwaggerBasicAuth();
                app.UseSwagger();
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Reporting Service API");
                });
            }

            ObjectProvider.container = app.ApplicationServices.GetAutofacRoot();
            LogExtensions.InitializeTaskPoolAndLogger(logWriterFactory, 10);
        }
    }
}
