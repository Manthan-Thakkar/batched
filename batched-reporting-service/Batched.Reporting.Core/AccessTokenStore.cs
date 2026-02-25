using Batched.Common;
using Batched.Common.Auth;
using Batched.Reporting.Contracts;

namespace Batched.Reporting.Core
{
    public class AccessTokenStore : IAccessTokenStore
    {
        private readonly Common.ICache _cache;
        public AccessTokenStore(Common.ICache cache)
        {
            _cache = cache;
        }

        public async Task<T> GetAccessTokenAsync<T>(string accessKey, CancellationToken cancellationToken)
        {
            return await _cache.GetAsync<T>(accessKey, DeserializeJson<T>, cancellationToken, false);
        }

        private static T DeserializeJson<T>(byte[] bytes)
        {
            try
            {
                using (Stream stream = new MemoryStream(bytes))
                {
                    JsonSerializer jsonSerializer = new JsonSerializer();
                    var tempObject = jsonSerializer.Deserialize<T>(stream);
                    return tempObject;
                }
            }
            catch (Exception)
            {
                throw new BaseApplicationException("500", "Error retrieving token from cache");
            }
        }
    }
}
