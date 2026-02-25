using Batched.Common.Data.Tenants.Sql.Models;

namespace Batched.Reporting.Test.MockedEntities
{
    public static class MockedLeadTimeExceptions
    {
        public static List<LeadTimeException> LeadTimeExceptions = new()
        {
            new()
            {
                Id= "4233c3a8-c524-4a2f-88c2-5b177955baf6",
                Name= "Priority Rule",
                Reason= "Jobs tagged with 'RUSH' priority will always receive 3 days lead time.",
                LeadTimeInDays= 3,
                CreatedBy= "Harry Potter",
                ModifiedBy= "Harry Potter",
                CreatedOnUtc= DateTime.UtcNow,
                ModifiedOnUtc= DateTime.UtcNow
            },
            new ()
            {
                Id= "4233c3a8-c524-4a2f-88c2-5b177955baf7",
                Name= "Ticket Rush",
                Reason= "Need to rush the jobs delivered within 7 days.",
                LeadTimeInDays= 7,
                CreatedBy= "Severus Snape",
                ModifiedBy= "Severus Snape",
                CreatedOnUtc= DateTime.UtcNow,
                ModifiedOnUtc= DateTime.UtcNow
            }
        };
    }
}