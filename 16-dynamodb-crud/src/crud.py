"""Lab 16 - CRUD on a DynamoDB table with boto3.  Usage: python src/crud.py"""
import os
import boto3
from boto3.dynamodb.conditions import Key

REGION = os.environ.get("AWS_REGION", "ap-southeast-2")
table = boto3.resource("dynamodb", region_name=REGION).Table("lab-16-books")


def create(book):
    # condition makes this a true "create": fails if the id already exists
    table.put_item(Item=book, ConditionExpression="attribute_not_exists(book_id)")
    print(f"CREATE  {book['book_id']}  {book['title']}")


def read(book_id):
    item = table.get_item(Key={"book_id": book_id}).get("Item")
    print(f"READ    {book_id}  ->  {item}")
    return item


def update(book_id, **fields):
    names = {f"#{k}": k for k in fields}
    values = {f":{k}": v for k, v in fields.items()}
    expr = "SET " + ", ".join(f"#{k} = :{k}" for k in fields)
    r = table.update_item(Key={"book_id": book_id}, UpdateExpression=expr,
                          ExpressionAttributeNames=names, ExpressionAttributeValues=values,
                          ConditionExpression="attribute_exists(book_id)", ReturnValues="ALL_NEW")
    print(f"UPDATE  {book_id}  ->  {r['Attributes']}")


def query_by_author(author):
    # Query on the GSI: efficient, reads only matching items (unlike scan)
    r = table.query(IndexName="author-index", KeyConditionExpression=Key("author").eq(author))
    print(f"QUERY   author={author!r}  ->  {[i['title'] for i in r['Items']]}")


def scan_all():
    items = table.scan()["Items"]
    print(f"SCAN    {len(items)} items  ->  {sorted(i['book_id'] for i in items)}")


def delete(book_id):
    table.delete_item(Key={"book_id": book_id}, ConditionExpression="attribute_exists(book_id)")
    print(f"DELETE  {book_id}")


if __name__ == "__main__":
    # reset to a known state so the demo is repeatable
    for i in table.scan()["Items"]:
        table.delete_item(Key={"book_id": i["book_id"]})
    create({"book_id": "b1", "title": "The Pragmatic Programmer", "author": "Hunt", "year": 1999, "stock": 5})
    create({"book_id": "b2", "title": "Clean Code", "author": "Martin", "year": 2008, "stock": 3})
    create({"book_id": "b3", "title": "Clean Architecture", "author": "Martin", "year": 2017, "stock": 2})
    create({"book_id": "b4", "title": "Temporary Book", "author": "Nobody", "year": 2000, "stock": 1})
    read("b1")
    update("b1", stock=4, year=2019)
    query_by_author("Martin")
    delete("b4")
    try:
        create({"book_id": "b1", "title": "Duplicate", "author": "X", "year": 1, "stock": 0})
    except table.meta.client.exceptions.ConditionalCheckFailedException:
        print("CREATE  b1  -> rejected (already exists): conditional write protected the data")
    scan_all()
