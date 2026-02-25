namespace Batched.Reporting.Test.MockedEntities
{
    public static class MockedStagingRequirementRequests
    {
        public static IEnumerable<object[]> GetStagingRequirementFilterRequest()
        {
            yield return new object[] { 1, null, null, new List<string>() };
            yield return new object[] { 2, DateTime.Parse("2024-07-23T00:00:00"), DateTime.Parse("2024-07-24T23:59:59"), new List<string>() };
            yield return new object[] { 3, null, null, new List<string>() { "04f6ffbc-7751-4c61-9591-ebf7fc409c6c" } };
        }
    }
}