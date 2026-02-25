#!/usr/bin/env python3
import sys, time
import boto3
from botocore.exceptions import ClientError

# Constants – customize as needed
EIP = "18.235.44.159"
MANAGED_TAG = {"Key": "ManagedBy", "Value": "EIP_Migration_Siteline"}

# Helpers
def get_eip_allocation(client):
    resp = client.describe_addresses(PublicIps=[EIP])
    return resp["Addresses"][0]["AllocationId"]

def get_eip_assoc(client):
    resp = client.describe_addresses(PublicIps=[EIP])
    return resp["Addresses"][0].get("AssociationId")

def get_nat_by_tag(client):
    resp = client.describe_nat_gateways(Filters=[
        {"Name": "tag:ManagedBy", "Values": [MANAGED_TAG["Value"]]},
        {"Name": "state", "Values": ["available","pending"]}
    ])
    return resp["NatGateways"][0]["NatGatewayId"] if resp["NatGateways"] else None

def wait_nat(client, nat_id, target_state):
    waiter = client.get_waiter(f'nat_gateway_{target_state}')
    waiter.wait(NatGatewayIds=[nat_id])
    return

def get_route(client, rt_id):
    resp = client.describe_route_tables(RouteTableIds=[rt_id])
    for route in resp["RouteTables"][0]["Routes"]:
        if route.get("DestinationCidrBlock") == "0.0.0.0/0":
            return route

def migrate(region, subnet_id, route_table_id, instance_id):
    ec2 = boto3.client('ec2', region_name=region)
    alloc_id = get_eip_allocation(ec2)

    assoc = get_eip_assoc(ec2)
    if assoc:
        print(f"Disassociating EIP {EIP}")
        ec2.disassociate_address(AssociationId=assoc)

    print("Creating NAT Gateway")
    resp = ec2.create_nat_gateway(
        SubnetId=subnet_id,
        AllocationId=alloc_id,
        TagSpecifications=[{"ResourceType":"natgateway","Tags":[MANAGED_TAG]}]
    )
    nat_id = resp["NatGateway"]["NatGatewayId"]
    wait_nat(ec2, nat_id, "available")
    print(f"NAT Gateway {nat_id} available")

    route = get_route(ec2, route_table_id)
    if route and "NatGatewayId" in route:
        prev = route["NatGatewayId"]
        print(f"Warning: Overwriting existing NAT Gateway {prev}")
    ec2.replace_route(
        RouteTableId=route_table_id,
        DestinationCidrBlock='0.0.0.0/0',
        NatGatewayId=nat_id
    )
    print(f"Route table {route_table_id} now uses NAT GW {nat_id}")

def rollback(region, route_table_id, instance_id):
    ec2 = boto3.client('ec2', region_name=region)
    nat_id = get_nat_by_tag(ec2)
    if not nat_id:
        print("No managed NAT Gateway found")
        return

    print("Repointing route to Old NAT Gateway")
    ec2.replace_route(
        RouteTableId=route_table_id,
        DestinationCidrBlock="0.0.0.0/0",
        NatGatewayId="nat-0208e207d14f6a095"
    )

    print(f"Deleting NAT Gateway {nat_id}")
    ec2.delete_nat_gateway(NatGatewayId=nat_id)
    wait_nat(ec2, nat_id, "deleted")

    alloc_id = get_eip_allocation(ec2)
    print(f"Reassociating EIP to instance")
    ec2.associate_address(InstanceId=instance_id, AllocationId=alloc_id)

def main():
    if len(sys.argv) < 6:
        print(f"Usage: {sys.argv[0]} migrate|rollback <region> <subnet-id> <route-table-id> <instance-id>")
        sys.exit(1)

    cmd, region, subnet, route_table, instance = sys.argv[1:6]
    if cmd == "migrate":
        migrate(region, subnet, route_table, instance)
    elif cmd == "rollback":
        rollback(region, route_table, instance)
    else:
        print("Unknown command:", cmd)
        sys.exit(1)

if __name__ == "__main__":
    main()

# export AWS_PROFILE=siteline-prod-sso
# aws sso login

# CMD - For SwitchOver - python3 eip_migration.py migrate us-east-1 subnet-439fa00a rtb-1d914364 i-08f6fe27826349dad
# CMD - For SwitchOver - python3 eip_migration.py rollback us-east-1 subnet-439fa00a rtb-1d914364 i-08f6fe27826349dad