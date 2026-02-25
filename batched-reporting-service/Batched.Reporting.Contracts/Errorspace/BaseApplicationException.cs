using System.Net;

namespace Batched.Reporting.Contracts
{
    public class BaseApplicationException : Exception
    {
        public string Code { get; set; }
        public HttpStatusCode? HttpStatusCode { get; set; }
        public List<Info> Infos { get; set; }
        public BaseApplicationException(string code, string message, HttpStatusCode? httpStatusCode, Exception? innerException, List<Info> infos) : base(message, innerException)
        {
            this.Code = code;
            if (httpStatusCode.HasValue)
                this.HttpStatusCode = httpStatusCode.Value;

            Infos = infos;

        }
        public BaseApplicationException(string code, string message)
            : this(code, message, null, null, null)
        {
        }
        public BaseApplicationException(string code, string message, HttpStatusCode httpStatusCode)
            : this(code, message, httpStatusCode, null, null)
        {
        }
        public BaseApplicationException(string code, string message, Exception exception)
            : this(code, message, null, exception, null)
        {
        }
        public BaseApplicationException(string code, string message, List<Info> infos)
            : this(code, message, null, null, infos)
        {

        }
    }
}
