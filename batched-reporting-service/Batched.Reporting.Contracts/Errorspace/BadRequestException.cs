using System.Net;

namespace Batched.Reporting.Contracts
{
    public class BadRequestException : BaseApplicationException
    {
        public BadRequestException(string code, string message) : base(code, message, System.Net.HttpStatusCode.BadRequest)
        {
        }

        public BadRequestException(string code, string message, HttpStatusCode httpStatusCode) : base(code, message, httpStatusCode)
        {
        }

        public BadRequestException(string code, string message, Exception exception) : base(code, message, exception)
        {
        }

        public BadRequestException(string code, string message, HttpStatusCode? httpStatusCode, Exception innerException) : base(code, message, httpStatusCode, innerException, null)
        {
        }
        public BadRequestException(string code, string message, List<Info> infos)
            : base(code, message, System.Net.HttpStatusCode.BadRequest, null, infos)
        {

        }
    }
}
