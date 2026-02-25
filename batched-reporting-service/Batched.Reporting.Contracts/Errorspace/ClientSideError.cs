using Batched.Reporting.Contracts.Errormap;
using Batched.Reporting.Shared;

namespace Batched.Reporting.Contracts
{
    public class ClientSideError
    {
        public static BaseApplicationException ParameterCannotBeNullOrEmpty(string fieldName)
        {
            return new BadRequestException(ErrorCodes.ParameterCannotBeNull, ErrorMessages.ParameterCannotBeNull.Format(fieldName));
        }
        public static BaseApplicationException InvalidRequest(List<Info> infos)
        {
            return new BadRequestException(ErrorCodes.InvalidRequest, ErrorMessages.InvalidRequest, infos);
        }
        public static BaseApplicationException InvalidRequest(string? message = null)
        {
            return new BadRequestException(ErrorCodes.InvalidRequest, message ?? ErrorMessages.InvalidRequest);
        }
    }
}
