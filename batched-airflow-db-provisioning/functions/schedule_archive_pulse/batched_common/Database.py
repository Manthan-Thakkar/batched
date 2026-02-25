import pyodbc
import sys
from botocore.exceptions import ClientError
import logging
from batched_common.SSM import *
from batched_common.Constants import *

class Database:
	def __init__(self):
		try:
			# Fetching connection string from parameter store
			aws_ssm_param = get_parameter(Constants.AWSPARAM_CONNECTIONSTRING, Constants.AWSPARAM_ENCRYPTION)
			self.connectionStr = aws_ssm_param['Parameter']['Value']
		except Exception as e:
			logging.error("Exception while reading from AWS Parameters")
			logging.error(e)
			raise e
		
	def getConnection(self):
		try:
			conn = pyodbc.connect(self.connectionStr, autocommit=True)
		except Exception as e:
			logging.error(e)
			return None
		return conn

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