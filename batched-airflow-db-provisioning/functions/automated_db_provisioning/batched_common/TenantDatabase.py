import pyodbc
from botocore.exceptions import ClientError
import logging
from batched_common.HttpClient import DBInstanceHttpClient, HttpClient
from batched_common.SSM import *
from batched_common.Constants import *

class TenantDatabase:
	def __init__(self, tenant_id, correlation_id):
		try:
			response = self.getConnectionString(tenant_id, correlation_id)
			self.setFullyQualifiedConnectionString(response)	
		except Exception as e:
			logging.error("Exception while get connection string for Tenant Id - "+tenant_id)
			logging.error(e)
			raise e

	def getConnectionString(self, tenant_id, correlation_id):
		try:
			# Fetching connection string from Db Instance Service
			httpclient = DBInstanceHttpClient()
			header = {"TenantId":tenant_id, "correlationId": correlation_id}
			url = Constants.API_GET_CONNECTIONSTRING + tenant_id
			response = httpclient.get(url, header)
		except Exception as e:
			print("Error in fetching connection string from Database Instance Service")
			logging.error(e)
			print(e)
			return None
		return response
	
	def setFullyQualifiedConnectionString(self, connectionDetails):
		try:
			if connectionDetails is not None:
				endpoint = connectionDetails['endpoint']
				port = str(connectionDetails['port'])
				userId = connectionDetails['userId']
				password = connectionDetails['password']
				dbName = connectionDetails['dbName']
				connection_string = "DRIVER={ODBC Driver 18 for SQL Server};SERVER="+endpoint+","+port+";UID="+userId+";PWD="+password
				connection_string_with_dbname = "DRIVER={ODBC Driver 18 for SQL Server};SERVER="+endpoint+","+port+";DATABASE="+dbName+";UID="+userId+";PWD="+password
				self.connectionString = connection_string
				self.connectionStrWithDBName = connection_string_with_dbname
			else:
				return None

		except Exception as e:
			logging.error(e)
			return None

	def getConnection(self):
		try:
			conn = pyodbc.connect(self.connectionString, autocommit=True)
		except Exception as e:
			logging.error(e)
			return None
		return conn
	
	def getConnectionWithDbName(self):
		try:
			conn = pyodbc.connect(self.connectionStrWithDBName, autocommit=True)
		except Exception as e:
			logging.error(e)
			return None
		return conn

	def executeSP(self,storedProcName,params=None,isDbNameRequired=False):
		if isDbNameRequired is True :
			conn = self.getConnectionWithDbName()
		else : 
			conn = self.getConnection()
		if conn is not None:
			try:
				cursor = conn.cursor()
				storedProc = "EXEC " + storedProcName

				#Append Params
				params_list = []
				if params is not None:
					for param in params:
						storedProc += " @" + param[0] + " = ?,"
						params_list.append(param[1])
					storedProc = storedProc[:-1]

				storedProcParams = tuple(params_list)
				cursor.execute(storedProc, storedProcParams)
				response = cursor.fetchall()
				cursor.close()
				del cursor
				conn.close()
			except Exception as e:
				logging.error(e)
				return None
			return response
		else:
			return None

	def ExecuteNonQuery(self,query):
		conn = self.getConnection()
		if conn is not None:
			try:
				cursor = conn.cursor()
				cursor.execute(query)
				cursor.close()
				del cursor
				conn.close()
			except Exception as e:
				logging.error(e)
				print(e)
				raise e

	def ExecuteReader(self,query):
		conn = self.getConnection()
		if conn is not None:
			try:
				cursor = conn.cursor()
				cursor.execute(query)
				response = cursor.fetchall()
				cursor.close()
				del cursor
				conn.close()
			except Exception as e:
				print("Error in executeReader method")
				logging.error(e)
				print(e)
				return None
			return response
		else:
			return None

