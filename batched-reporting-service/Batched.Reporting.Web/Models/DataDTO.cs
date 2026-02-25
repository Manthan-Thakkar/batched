namespace Batched.Reporting.Web.Models
{
    /// <summary>
    /// Common data DTO model.
    /// </summary>
    public class DataDTO
    {
        /// <summary>
        /// Id of the field.
        /// </summary>
        /// <example>"4233c3a8-c524-4a2f-88c2-5b177955baf6"</example>
        public string Id { get; set; }

        /// <summary>
        /// Name or Display Name of the field such as ValueStream name or StagingRequirement name.
        /// </summary>
        /// <example>"Field Name"</example>
        public string Name { get; set; }
    }
}
