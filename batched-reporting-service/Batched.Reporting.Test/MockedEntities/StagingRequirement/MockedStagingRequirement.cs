using CommonModels = Batched.Common.Data.Tenants.Sql.Models;
using Newtonsoft.Json;
using Batched.Reporting.Contracts.Models.StagingRequirement;

namespace Batched.Reporting.Test.MockedEntities.StagingRequirement
{
    public class MockedStagingRequirement
    {
        public static List<CommonModels.StagingRequirement> GetStagingRequirements()
        {
            var jsonStagingRequirement = File.ReadAllText("./Data/StagingRequirements.json");
            var StagingRequirements = JsonConvert.DeserializeObject<List<CommonModels.StagingRequirement>>(jsonStagingRequirement);
            return StagingRequirements;
        }

        public static List<CommonModels.StagingRequirementGroup> GetWorkcenterStagingRequirements()
        {
            var jsonStagingRequirementGroup = File.ReadAllText("./Data/StagingRequirementGroup.json");
            var StagingRequirementGroups = JsonConvert.DeserializeObject<List<CommonModels.StagingRequirementGroup>>(jsonStagingRequirementGroup);
            return StagingRequirementGroups;
        }

        public static List<StagingReportFilterData> GetStagingRequirementFilterData()
        {
            var jsonStagingFilterData = File.ReadAllText("./Data/StagingFilterControllerData.json");
            var stagingFilterData = JsonConvert.DeserializeObject<List<StagingReportFilterData>>(jsonStagingFilterData);
            return stagingFilterData;
        }
    }
}
