from batched_common.TenantDatabase import TenantDatabase
import logging
import time
from batched_common.SSM import *
from batched_common.Database import *
from batched_common.Constants import *

def SeedTenantData(event):
    try:
        #batched db connection setup
        batched_rds = Database() 
        #tenant db connection setup
        tenant_id = event[Constants.DAGRUNPARAM_TENANTID]
        correlation_id = event[Constants.DAGRUNPARAM_CORRELATIONID]
        tenant_rds = TenantDatabase(tenant_id, correlation_id) 
    except Exception as e:
        logging.error("Exception while creating Database object")
        logging.error(e)
        print(e)
        return False
    
    try:
        # Fetching seeding data from batched Database
        params = [["tenantId", tenant_id]]
        fetched_seed_data = batched_rds.executeSPwithMultipeReturn('spGetSeedTenantData',params)

        if fetched_seed_data is not None:
            ticket_attributes = fetched_seed_data[0]
            ticket_attribute_formulae  = fetched_seed_data[1]
            task_classification_groups  = fetched_seed_data[2]
            master_roll_classification_group  = fetched_seed_data[3]
            time_zone = fetched_seed_data[4]
            seedparams = [["TenantId", tenant_id], ["CorelationId", correlation_id], ["ticketAttribute", ticket_attributes ],["ticketAttributeFormula", ticket_attribute_formulae], ["taskClassificationGroup", task_classification_groups], ["masterRollClassificationGroup", master_roll_classification_group ], ["timezone",time_zone ] ]
            save_seed_response = tenant_rds.executeSP('[dbo].[spSeedTenantData]',seedparams,True)
            if save_seed_response is not None :
                logging.info("Saved Seed data successfully")
                event['stepsDetails']['stepStatus'] = 'SUCCESS'
                event['stepsDetails']['NextStep'] = 'UpdateStatus-For-Tenant'
                return event
            else:
                event['stepsDetails']['stepStatus'] = 'ERROR'
                event['stepsDetails']['NextStep'] = 'UpdateStatus-For-Tenant'
                logging.info("Saved Seed data failed")

                return event

        else:
            logging.error("No seed data found")
            event['stepsDetails']['stepStatus'] = 'NoSeedDataFound'
            event['stepsDetails']['NextStep'] = 'UpdateStatus-For-Tenant'
            return event
    except Exception as e:
        logging.error("Exception while Seeding Tenant Data")
        logging.error(e)
        print(e)
        event['stepsDetails']['stepStatus'] = 'ERROR'
        event['stepsDetails']['NextStep'] = 'UpdateStatus-For-Tenant'
        return event