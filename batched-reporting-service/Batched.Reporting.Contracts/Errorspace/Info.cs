namespace Batched.Reporting.Contracts
{
    public class Info
    {
        public string Code { get; private set; }
        public string Message { get; private set; }
        public Info(string code, string message)
        {
            if (string.IsNullOrWhiteSpace(code))
                throw ClientSideError.ParameterCannotBeNullOrEmpty("code");
            if (string.IsNullOrWhiteSpace(message))
                throw ClientSideError.ParameterCannotBeNullOrEmpty("message");
            Code = code;
            Message = message;
        }
        public static List<Info> Create() => new List<Info>();
    }

    public static class InfoExtention
    {
        public static List<Info> AddInfo(this List<Info> info, string code, string message)
        {
            if (info == null)
                info = new List<Info>();

            info.Add(new Info(code, message));

            return info;
        }
    }
}
