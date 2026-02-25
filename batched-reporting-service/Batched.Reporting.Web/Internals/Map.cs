namespace Batched.Reporting.Web
{
    public class Map
    {
        private readonly Dictionary<string, string> _map;
        private Map()
        {
            _map = new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase);
        }

        public static Map Create => new Map();
        public Map Add(string key, string value)
        {
            _map[key] = value;
            return this;
        }
        public string GetValue(string key)
        {
            if (_map.ContainsKey(key))
                return _map[key];
            return string.Empty;
        }
    }
}
