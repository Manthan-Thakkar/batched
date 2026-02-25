using Autofac;
using Batched.Common;
using Batched.Common.Cache.Redis;
using Batched.DBInstanceService.Sdk;
using Batched.Reporting.Core; 

namespace Batched.Reporting.Web
{
    public class RegistryModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<SerializerFactory>().As<ISerializerFactory>();
            builder.RegisterType<JsonSerializer>().As<ISerializer>();
            builder.RegisterType<WebClient>().As<IWebClient>();
            builder.RegisterType<RedisCache>().As<ICache>();
            builder.RegisterType<DBConnectionInfoProvider>().As<IDBConnectionInfoProvider>();

            builder.RegisterType<ObjectProvider>().As<IObjectProvider>();
        }
    }
}
