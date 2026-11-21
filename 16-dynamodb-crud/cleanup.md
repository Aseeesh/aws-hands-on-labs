# Cleanup

Deletes the table, its index and all items (this cannot be undone):

```bash
aws dynamodb delete-table --table-name lab-16-books
aws dynamodb wait table-not-exists --table-name lab-16-books
```

Verify (expect `ResourceNotFoundException`):
```bash
aws dynamodb describe-table --table-name lab-16-books
```

Console: DynamoDB → Tables → select `lab-16-books` → **Delete**.
