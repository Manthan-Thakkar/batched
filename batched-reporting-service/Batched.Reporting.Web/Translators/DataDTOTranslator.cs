using Batched.Reporting.Web.Models;
using ContractModels = Batched.Reporting.Contracts.Models;

namespace Batched.Reporting.Web.Translators
{
    /// <summary>
    /// Trasnslator for common Data DTO objects.
    /// </summary>
    public static class DataDTOTranslator
    {
        /// <summary>
        /// Trasnslator for Data DTO object.
        /// </summary>
        public static List<DataDTO> Translate(this List<ContractModels.DataDTO> dtos)
        {
            if (dtos == null)
                return null;

            var response = new List<DataDTO>();

            foreach (var dto in dtos)
            {
                response.Add(dto.Translate());
            }

            return response;
        }

        private static DataDTO Translate(this ContractModels.DataDTO dto)
        {
            if (dto == null)
                return null;

            return new DataDTO
            {
                Id = dto.Id,
                Name = dto.Name
            };
        }
    }
}