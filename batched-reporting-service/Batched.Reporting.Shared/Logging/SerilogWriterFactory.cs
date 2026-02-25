using Batched.Common;

namespace Batched.Reporting.Shared
{
    public class SerilogWriterFactory : ILogWriterFactory
    {
        private IApplicationLogWriter logWriter;
        private readonly ILogSink logSink;
        private readonly IConfigProvider configProvider;
        public SerilogWriterFactory(ILogSink logSink, IConfigProvider configProvider)
        {
            this.logSink = logSink;
            this.configProvider = configProvider;
        }
        public IApplicationLogWriter CreateWriter()
        {
            if (logWriter == null)
            {
                var _logSink = new CompositeSink(null, new List<ILogSink> { logSink });
                logWriter = new LogWriter(JsonLogFormatter.Instance, _logSink, configProvider);
            }
            return logWriter;
        }
    }
}
