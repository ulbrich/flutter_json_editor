const complexSchemaMap = {
  "\$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Employee Record",
  "type": "object",
  "required": ["firstName", "lastName", "employeeType"],
  "properties": {
    "firstName": {
      "type": "string",
      "title": "First Name",
      "description": "Employee's first name",
      "minLength": 1,
      "maxLength": 50
    },
    "lastName": {"type": "string", "title": "Last Name", "minLength": 1},
    "age": {"type": "integer", "title": "Age", "minimum": 18, "maximum": 120},
    "email": {"type": "string", "title": "Email", "format": "email"},
    "isActive": {
      "type": "boolean",
      "title": "Active Employee",
      "default": true
    },
    "employeeType": {
      "type": "string",
      "title": "Employee Type",
      "enum": ["full-time", "part-time", "contractor", "intern"],
    },
    "hobby": {
      "type": "string",
      "title": "Hobby",
      "\$ref": "https://example.com/api/hobbies"
    },
    "department": {
      "type": ["string", "null"],
      "title": "Department",
      "description": "Nullable department field"
    },
    "address": {
      "type": "object",
      "title": "Address",
      "description": "Home address",
      "required": ["street", "city"],
      "properties": {
        "street": {"type": "string", "title": "Street"},
        "city": {"type": "string", "title": "City"},
        "state": {"type": "string", "title": "State"},
        "zipCode": {
          "type": "string",
          "title": "ZIP Code",
          "pattern": "^[0-9]{5}\$"
        }
      }
    },
    "skills": {
      "type": "array",
      "title": "Skills",
      "description": "List of skills",
      "items": {"type": "string"},
      "minItems": 1,
      "maxItems": 10
    },
    "tags": {
      "type": "object",
      "title": "Custom Tags",
      "description": "Arbitrary key-value tags",
      "additionalProperties": {"type": "string"}
    },
    "favouriteColour": {
      "type": "string",
      "x-format": "colour",
      "title": "Favourite Colour",
      "description": "Pick your favourite colour",
      "default": "#ff0000"
    },
    "notes": {"type": "string", "title": "Internal Notes", "readOnly": true}
  },
  "if": {
    "properties": {
      "employeeType": {"const": "contractor"}
    }
  },
  "then": {
    "properties": {
      "contractEndDate": {
        "type": "string",
        "title": "Contract End Date",
        "format": "date"
      },
      "hourlyRate": {"type": "number", "title": "Hourly Rate", "minimum": 0}
    },
    "required": ["contractEndDate"]
  },
  "else": {
    "properties": {
      "salary": {"type": "number", "title": "Annual Salary", "minimum": 0}
    }
  }
};

const complexSchemaHobbyRefLookupResponse = {
  "type": "string",
  "enumSource": [
    {
      "value": "{{item.value}}",
      "title": "{{item.title}}",
      "source": [
        {"value": "53323990-f4c8-4a25-8d83-a9313a403331", "title": "cooking"},
        {"value": "3562eb73-a2be-ed86-26bd-28f18956c5b3", "title": "dancing"},
        {"value": "607f1626-8766-43d6-9931-bdde327e0cf1", "title": "filming"},
        {"value": "750b209c-cce5-4dc7-a4fa-6c76019ba73f", "title": "gardening"},
        {"value": "98b21842-e696-401a-bb6e-b0afdad6ed24", "title": "music"},
        {"value": "e9287e38-5e14-45ed-a026-3e37295c7828", "title": "painting"},
        {"value": "ba337609-a6af-875d-1282-b202be8c55ba", "title": "reading"},
        {"value": "a248b9d7-fdfd-4bc8-bab0-73a11443bb0e", "title": "sports"},
        {"value": "50caf221-2ac9-4dda-aa7d-e8f9238ba86c", "title": "traveling"},
        {"value": "ddcbe404-f7e7-494c-b0de-e76689cff554", "title": "writing"}
      ]
    }
  ]
};
