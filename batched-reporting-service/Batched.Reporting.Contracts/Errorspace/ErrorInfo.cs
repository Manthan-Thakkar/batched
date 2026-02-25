namespace Batched.Reporting.Contracts
{
    public class ErrorInfo
    {
        public string Code { get; private set; }
        public string Message { get; private set; }
        public ErrorInfo(string code, string message)
        {
            if (string.IsNullOrWhiteSpace(code))
                throw ClientSideError.ParameterCannotBeNullOrEmpty("code");
            if (string.IsNullOrWhiteSpace(message))
                throw ClientSideError.ParameterCannotBeNullOrEmpty("message");
            Code = code;
            Message = message;
        }
        public List<Info> Infos { get; set; } = new List<Info>();
    }
}
