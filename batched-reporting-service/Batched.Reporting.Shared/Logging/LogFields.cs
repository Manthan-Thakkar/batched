using System.Collections;
using System.Collections.Generic;

namespace Batched.Reporting.Shared
{
    public class LogFields : IEnumerable<KeyValuePair<string, object>>
    {
        private readonly Dictionary<string, object> _fields;
        private LogFields()
        {
            _fields = new Dictionary<string, object>();
        }

        public static LogFields Create => new LogFields();
        public LogFields Add(string key, object value)
        {
            _fields[key] = value;
            return this;
        }
        internal IDictionary<string, object> GetMap() => _fields;
        public IEnumerator<KeyValuePair<string, object>> GetEnumerator()
        {
            foreach (var field in _fields)
                yield return field;
        }
        IEnumerator IEnumerable.GetEnumerator()
        {
            return this.GetEnumerator();
        }
    }
}
