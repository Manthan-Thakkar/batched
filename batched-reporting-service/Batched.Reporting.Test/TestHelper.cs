using Batched.Common;
using Moq;
using Batched.Reporting.Shared;

namespace Batched.Reporting.Test
{
    public class TestHelper
    {
        protected T Mock<T>() => It.IsAny<T>();
        protected CancellationToken MockedCToken() => It.IsAny<CancellationToken>();
        protected List<T> ListOf<T>(params T[] obj) => new List<T>(obj);
        protected void WithScope(Action callback)
        {
            using (new AmbientContextScope(new ApplicationContext("", "", "", "", null, null)))
            {
                callback();
            };
        }
    }
}
