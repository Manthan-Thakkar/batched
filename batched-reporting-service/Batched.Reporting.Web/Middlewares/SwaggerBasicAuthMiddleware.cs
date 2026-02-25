using Microsoft.Extensions.Options;
using System.Text;

namespace Batched.Reporting.Web
{
    /// <summary>
    /// Middle to handle the swagger basic authentication.
    /// </summary>
    public class SwaggerBasicAuthMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly string _username;
        private readonly string _password;

        /// <summary>
        /// Constructor set the configuration values.
        /// </summary>
        /// <param name="next"></param>
        /// <param name="options"></param>
        public SwaggerBasicAuthMiddleware(RequestDelegate next, IOptions<SwaggerAuthOptions> options)
        {
            _next = next;
            _username = options.Value.Username ?? string.Empty;
            _password = options.Value.Password ?? string.Empty;
        }

        /// <summary>
        /// Middleware invoke method to execute the authentication logic
        /// </summary>
        /// <param name="context">HttpContext</param>
        /// <returns></returns>
        public async Task Invoke(HttpContext context)
        {
            // Check if the request is for the Swagger UI endpoint
            if (context.Request.Path.StartsWithSegments("/swagger"))
            {
                string authHeader = context.Request.Headers["Authorization"];
                if (authHeader != null && authHeader.StartsWith("Basic "))
                {
                    // Extract credentials from Authorization header
                    string encodedUsernamePassword = authHeader.Split(' ', 2)[1]?.Trim();
                    string decodedUsernamePassword = Encoding.UTF8.GetString(Convert.FromBase64String(encodedUsernamePassword));
                    string username = decodedUsernamePassword.Split(':', 2)[0];
                    string password = decodedUsernamePassword.Split(':', 2)[1];

                    // Validate credentials
                    if (username == _username && password == _password)
                    {
                        await _next.Invoke(context);
                        return;
                    }
                }

                // Unauthorized
                context.Response.Headers["WWW-Authenticate"] = "Basic realm=\"Swagger UI\"";
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            }
            else
            {
                // Pass the request to the next middleware in the pipeline
                await _next.Invoke(context);
            }
        }
    }

    /// <summary>
    /// Swagger Auth Middleware extension to set the middleware in IApplicationBuilder
    /// </summary>
    public static class SwaggerBasicAuthMiddlewareExtensions
    {
        /// <summary>
        /// Sets the SwaggerBasicAuth
        /// </summary>
        /// <param name="builder"></param>
        /// <returns></returns>
        public static IApplicationBuilder UseSwaggerBasicAuth(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<SwaggerBasicAuthMiddleware>();
        }
    }
}
