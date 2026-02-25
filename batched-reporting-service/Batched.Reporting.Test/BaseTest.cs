using Xunit;

namespace Batched.Reporting.Test
{
    public class BaseTest<TType> : TestHelper
    {
        private readonly Type _sub;
        private readonly Type[] _params;
        public BaseTest(params Type[] types)
        {
            _sub = typeof(TType);
            _params = types ?? Array.Empty<Type>();
            TestAll();
        }
        private void Type_ShouldHave_OnlyOneCtor()
        {
            Assert.True(_sub.GetConstructors().Length == 1);
        }
        private void Type_ShouldHavePublic_Ctor()
        {
            var ctor = _sub.GetConstructors()[0];

            Assert.True(ctor.IsPublic);
        }
        private void Type_ShouldNotHave_StaticCtor()
        {
            var ctor = _sub.GetConstructors()[0];
            Assert.False(ctor.IsStatic);
        }
        private void TypeCtor_ShouldHaveExactNumberOfParams()
        {
            var ctors = _sub.GetConstructors();
            Assert.True(ctors.Length > 0);
            var parameters = ctors[0].GetParameters();

            Assert.Equal(parameters.Length, _params.Length);
        }
        private void CheckAll_Ctor_ParamType_Is_Matching()
        {
            var ctors = _sub.GetConstructors();
            Assert.True(ctors.Length > 0);
            var parameters = ctors[0].GetParameters();

            foreach (var parameter in parameters)
            {
                Assert.Contains(_params, p => p.IsAssignableFrom(parameter.ParameterType));
            }
        }
        private void TestAll()
        {
            Type_ShouldHave_OnlyOneCtor();
            Type_ShouldHavePublic_Ctor();
            Type_ShouldNotHave_StaticCtor();
            TypeCtor_ShouldHaveExactNumberOfParams();
            CheckAll_Ctor_ParamType_Is_Matching();
        }
    }
}
