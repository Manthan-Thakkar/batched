using Batched.Common;

namespace Batched.Reporting.Core
{
    public class SerializerFactory : ISerializerFactory
    {
        public ISerializer Create(string serializerFor)
        {
            return new JsonSerializer();
        }
    }
}
