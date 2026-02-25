import requests
import sys
import json

from requests.api import head
from batched_common.SSM import *
from batched_common.Constants import *

class HttpClient:
	def __init__(self, url_source):
		try:
			# Fetching connection string from parameter store
			aws_param = get_parameter(url_source, Constants.AWSPARAM_ENCRYPTION)
			print(aws_param)
			self.baseUrl = aws_param['Parameter']['Value']
		except Exception as e:
			#logging.error("Exception while reading from AWS Parameters")
			#logging.error(e)
			raise e
		
	def get(self,url, headers=None):
		try:
			targetUrl = self.baseUrl + url
			print(targetUrl)
			#logging.info(headers)
			r = requests.get(targetUrl, headers=headers)
			if 200 <= r.status_code <= 299:
				return r.json()
			else:
				raise Exception("api failed")
		except Exception as e:
			#logging.error(e)
			raise e

class RulesEngineHttpClient(HttpClient):
	def __init__(self):
		super().__init__(Constants.AWSPARAM_RULES_ENGINE_URL)