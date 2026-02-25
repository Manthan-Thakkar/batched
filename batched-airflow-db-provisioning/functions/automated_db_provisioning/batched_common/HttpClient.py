import requests
import logging

from requests.api import head
from batched_common.SSM import *
from batched_common.Constants import *

class HttpClient:
	def __init__(self, url_source):
		try:
			# Fetching connection string from parameter store
			aws_param = get_parameter(url_source, Constants.AWSPARAM_ENCRYPTION)
			self.baseUrl = aws_param['Parameter']['Value']
		except Exception as e:
			logging.error("Exception while reading from AWS Parameters")
			logging.error(e)
			raise e
		
	def get(self,url, headers=None):
		try:
			targetUrl = self.baseUrl + url
			print(targetUrl)
			logging.info(headers)
			r = requests.get(targetUrl, headers=headers)
			if 200 <= r.status_code <= 299:
				return r.json()
			else:
				raise Exception("api failed")
		except Exception as e:
			logging.error(e)
			raise e

	def post(self,url,body, headers=None):
		try:
			targetUrl = self.baseUrl + url
			print(targetUrl)
			logging.info(headers)
			r = requests.post(targetUrl,data=body, headers=headers)
			print(r.status_code)
			print(r.json())
		except Exception as e:
			logging.error(e)
			print(e)
			raise e

	def postAsync(self,url,body, headers=None):
		try:
			targetUrl = self.baseUrl + url
			requests.post(targetUrl, data=body, headers=headers, timeout=5)
		except Exception as e:
			logging.error(e)
			print(e)
			raise e

	def delete(self, url, headers=None):
		try:
			targetUrl = self.baseUrl + url
			print(targetUrl)
			logging.info(headers)
			r = requests.delete(targetUrl, headers=headers)
			print(r.status_code)
			print(r.json())
			if 200 <= r.status_code <= 299:
				return r.json()
			else:
				raise Exception("api failed")
		except Exception as e:
			logging.error(e)
			raise e

class DBInstanceHttpClient(HttpClient):
	def __init__(self):
		super().__init__(Constants.AWSPARAM_DB_INSTANCE_SERVICE_URL)