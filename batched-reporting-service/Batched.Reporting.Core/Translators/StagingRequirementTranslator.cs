using Batched.Reporting.Contracts.Models.StagingRequirement;
using CommonModels = Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Core.Translators
{
    public static class StagingRequirementTranslator
    {
        public static FacilityScheduledTime Translate(this CommonModels.FacilityScheduledTime facilityScheduledTime)
        {
            if (facilityScheduledTime == null)
                return null;

            return new FacilityScheduledTime
            {
                NextScheduledTime = facilityScheduledTime.NextScheduledTime,
                ScheduledFacilities = facilityScheduledTime.ScheduledFacilities.Translate()
            };
        }

        private static List<ScheduledFacility> Translate(this List<CommonModels.ScheduledFacility> scheduledFacility)
        {
            if (scheduledFacility == null)
                return null;

            var response = new List<ScheduledFacility>();

            foreach (var schedule in scheduledFacility)
            {
                response.Add(new ScheduledFacility
                {
                    FacilityId = schedule.FacilityId,
                    FacilityName = schedule.FacilityName,
                    TimeZone = schedule.TimeZone,
                    FacilityTimeStamp = schedule.FacilityTimeStamp,
                    UTCTimeStamp = schedule.UTCTimeStamp,
                    ValueStreamId = schedule.ValueStreamId,
                    ValueStreamName = schedule.ValueStreamName
                });
            }

            return response;
        }
    }
}