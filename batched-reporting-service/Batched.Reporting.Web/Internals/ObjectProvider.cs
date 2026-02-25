using Autofac;
using Batched.Common;

namespace Batched.Reporting.Web
{
    public class ObjectProvider : IObjectProvider
    {
        public static ILifetimeScope container { get; internal set; }
        public IEnumerable<object> GetAllInstances(Type serviceType)
        {
            throw new NotImplementedException();
        }

        public IEnumerable<TService> GetAllInstances<TService>()
        {
            return container.Resolve<IEnumerable<TService>>();
        }

        public object GetInstance(Type serviceType)
        {
            return container.Resolve(serviceType);
        }

        public object GetInstance(Type serviceType, string key)
        {
            return container.ResolveNamed(key, serviceType);
        }

        public TService GetInstance<TService>()
        {
            return container.Resolve<TService>();
        }

        public TService GetInstance<TService>(string key)
        {
            return  container.ResolveNamed<TService>(key);
        }

        public bool TryGetInstance<TService>(out TService service)
            where TService : class
        {
            return container.TryResolve(out service);
        }

        public bool TryGetInstance<TService>(string key, out TService service)
            where TService : class
        {
            if (container.TryResolveNamed(key, typeof(TService), out object obj) && obj is TService _service)
            {
                service = _service;
                return true;
            }
            service = default;
            return false;
        }
    }
}
