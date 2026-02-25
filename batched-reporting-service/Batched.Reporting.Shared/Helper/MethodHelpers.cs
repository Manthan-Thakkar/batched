namespace Batched.Reporting.Shared.Helper
{
    public static class MethodHelpers
    {
        public static string GetStagingNameKey(this string stagingName)
        {
            return string.Concat("Is", stagingName.Replace(" ", ""), "Staged");
        }
    }
}