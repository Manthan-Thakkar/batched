using Batched.Common.Data.Sql.Extensions;
using Microsoft.Data.SqlClient;
using System.Data;

namespace Batched.Reporting.Data
{
    public static class RepositoryHelper
    {
        public static DataTable GetSingleValueDataTable(List<string> values)
        {
            var dt = DataTableBuilder.Create(values)
                .AddColumn("Field", x => x)
                .Build();

            return dt;
        }

        public static DataTableCollection ExecuteCommand(string spName, string connectionString, List<SPParam> parameters)
        {
            var _connection = new SqlConnection(connectionString);
            try
            {
                _connection.Open();
                using SqlCommand cmd = new SqlCommand(spName, _connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                cmd.CommandTimeout = 300;
                if (parameters != null && parameters.Count > 0)
                {
                    foreach (var param in parameters)
                    {
                        cmd.Parameters.Add($"@{param.Name}", param.SqlDbType).Value = param.Value;
                    }
                }
                var adapter = new SqlDataAdapter(cmd);

                DataSet ds = new DataSet();
                adapter.Fill(ds);

                DataSetHelper.SetTableNames(ds.Tables);

                return ds.Tables;

            }
            catch (Exception ex)
            {
                ex.Data.Add("sp_name", spName);
                throw;
            }
            finally
            {
                if (_connection.State == ConnectionState.Open)
                    _connection.Close();
            }
        }
    }
}