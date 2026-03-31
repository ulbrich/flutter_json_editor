const exampleSchemaMap = {
  'en': _exampleSchemaEnglish,
  'de': _exampleSchemaGerman,
};

const _exampleSchemaEnglish = {
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
    "lastName": {
      "type": "string",
      "title": "Last Name",
      "description": "Please update if changed, e.g. after marriage",
      "minLength": 1,
    },
    "age": {
      "type": "integer",
      "title": "Age",
      "minimum": 18,
      "maximum": 120,
    },
    "email": {
      "type": "string",
      "title": "Email",
      "format": "email",
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
    "seating": {
      "type": "string",
      "x-format": "svg-part-picker",
      "x-svg-asset": "assets/images/office-plan.svg",
      "title": "Allocated Desk",
      "description":
          "Select the allocated desk in the office from the floor plan"
    },
    "themeColour": {
      "type": "string",
      "x-format": "colour",
      "title": "Theme Colour",
      "description": "Pick your colour for UX theming",
      "default": "#ff0000"
    },
    "avatar": {
      "type": "string",
      "x-format": "image-url-picker",
      "title": "Avatar",
      "description": "Choose a profile picture",
      "\$ref": "https://example.com/api/avatars"
    },
    "hobby": {
      "type": "string",
      "title": "Hobby",
      "\$ref": "https://example.com/api/hobbies"
    },
    "notes": {
      "type": "string",
      "x-format": "markdown",
      "title": "Internal Notes",
      "readOnly": true
    },
    "department": {
      "type": ["string", "null"],
      "title": "Department",
      "description": "Nullable department field"
    },
    "preferredMeetingTime": {
      "type": "string",
      "x-format": "time",
      "title": "Preferred Meeting Time",
      "description": "Preferred time for daily stand-up"
    },
    "isActive": {
      "type": "boolean",
      "title": "Active Contract",
      "default": true
    },
    "lastCheckIn": {
      "type": "string",
      "x-format": "date-time",
      "title": "Last Check-In",
      "description": "Most recent check-in date and time"
    },
    "performance": {
      "type": "integer",
      "x-format": "star-rating",
      "title": "Performance Rating",
      "description": "Rate employee performance (0–5 stars)",
      "minimum": 0,
      "maximum": 5,
      "default": 0
    },
    "employeeType": {
      "type": "string",
      "title": "Employee Type",
      "enum": ["full-time", "part-time", "contractor", "intern"],
    },
    "contractStartDate": {
      "type": "string",
      "x-format": "date",
      "title": "Contract Start Date",
      "description": "Date when the employee started"
    },
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
      "hourlyRate": {
        "type": "number",
        "title": "Hourly Rate",
        "minimum": 0,
      }
    },
    "required": ["contractEndDate"]
  },
  "else": {
    "properties": {
      "salary": {
        "type": "number",
        "title": "Annual Salary",
        "minimum": 0,
      }
    }
  },
};

const _exampleSchemaGerman = {
  "\$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Mitarbeiterdaten",
  "type": "object",
  "required": ["firstName", "lastName", "employeeType"],
  "properties": {
    "firstName": {
      "type": "string",
      "title": "Vorname",
      "minLength": 1,
      "maxLength": 50
    },
    "lastName": {
      "type": "string",
      "title": "Nachname",
      "description": "Bitte nach z.B. Hochzeit unbedingt anpassen",
      "minLength": 1,
    },
    "age": {
      "type": "integer",
      "title": "Alter",
      "minimum": 18,
      "maximum": 120,
    },
    "email": {
      "type": "string",
      "title": "E-Mail",
      "format": "email",
    },
    "address": {
      "type": "object",
      "title": "Adresse",
      "description": "Privatadresse",
      "required": ["street", "city"],
      "properties": {
        "street": {"type": "string", "title": "Straße"},
        "city": {"type": "string", "title": "Stadt"},
        "state": {"type": "string", "title": "Bundesland"},
        "zipCode": {
          "type": "string",
          "title": "Postleitzahl",
          "pattern": "^[0-9]{5}\$"
        }
      }
    },
    "skills": {
      "type": "array",
      "title": "Fähigkeiten",
      "description": "Liste der Fähigkeiten",
      "items": {"type": "string"},
      "minItems": 1,
      "maxItems": 10
    },
    "tags": {
      "type": "object",
      "title": "Eigene Tags",
      "description": "Frei definierbare Schlüssel-Wert-Paare",
      "additionalProperties": {"type": "string"}
    },
    "seating": {
      "type": "string",
      "x-format": "svg-part-picker",
      "x-svg-asset": "assets/images/office-plan.svg",
      "title": "Zugewiesener Schreibtisch",
      "description":
          "Wählen Sie den zugewiesenen Schreibtisch im Büro aus dem Raumplan"
    },
    "themeColour": {
      "type": "string",
      "x-format": "colour",
      "title": "Designfarbe",
      "description": "Wählen Sie Ihre Farbe für das UX-Design",
      "default": "#ff0000"
    },
    "avatar": {
      "type": "string",
      "x-format": "image-url-picker",
      "title": "Profilbild",
      "description": "Wählen Sie ein Profilbild",
      "\$ref": "https://example.com/api/avatars"
    },
    "hobby": {
      "type": "string",
      "title": "Hobby",
      "\$ref": "https://example.com/api/hobbies"
    },
    "notes": {
      "type": "string",
      "x-format": "markdown",
      "title": "Interne Notizen",
      "readOnly": true
    },
    "department": {
      "type": ["string", "null"],
      "title": "Abteilung",
      "description": "Optionales Abteilungsfeld"
    },
    "preferredMeetingTime": {
      "type": "string",
      "x-format": "time",
      "title": "Bevorzugte Besprechungszeit",
      "description": "Bevorzugte Uhrzeit für das tägliche Stand-up"
    },
    "isActive": {
      "type": "boolean",
      "title": "Aktiver Vertrag",
      "default": true
    },
    "lastCheckIn": {
      "type": "string",
      "x-format": "date-time",
      "title": "Letzter Check-in",
      "description": "Datum und Uhrzeit des letzten Check-ins"
    },
    "performance": {
      "type": "integer",
      "x-format": "star-rating",
      "title": "Leistungsbewertung",
      "description": "Leistung des Mitarbeiters bewerten (0–5 Sterne)",
      "minimum": 0,
      "maximum": 5,
      "default": 0
    },
    "employeeType": {
      "type": "string",
      "title": "Beschäftigungsart",
      "enum": ["full-time", "part-time", "contractor", "intern"],
    },
    "contractStartDate": {
      "type": "string",
      "x-format": "date",
      "title": "Vertragsbeginn",
      "description": "Datum des Arbeitsbeginns"
    },
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
        "title": "Vertragsende",
        "format": "date"
      },
      "hourlyRate": {
        "type": "number",
        "title": "Stundensatz",
        "minimum": 0,
      }
    },
    "required": ["contractEndDate"]
  },
  "else": {
    "properties": {
      "salary": {
        "type": "number",
        "title": "Jahresgehalt",
        "minimum": 0,
      }
    }
  },
};

const exampleSchemaAvatarRefLookupResponse = {
  "type": "string",
  "enumSource": [
    {
      "value": "{{item.value}}",
      "title": "{{item.title}}",
      "source": [
        {
          "value": "avatar-1",
          "title": "https://api.dicebear.com/9.x/thumbs/png?seed=Felix&size=128"
        },
        {
          "value": "avatar-2",
          "title": "https://api.dicebear.com/9.x/thumbs/png?seed=Aneka&size=128"
        },
        {
          "value": "avatar-3",
          "title": "https://api.dicebear.com/9.x/thumbs/png?seed=Lily&size=128"
        },
        {
          "value": "avatar-4",
          "title": "https://api.dicebear.com/9.x/thumbs/png?seed=Max&size=128"
        },
        {
          "value": "avatar-5",
          "title": "https://api.dicebear.com/9.x/thumbs/png?seed=Sam&size=128"
        },
        {
          "value": "avatar-6",
          "title": "https://api.dicebear.com/9.x/thumbs/png?seed=Zoe&size=128"
        }
      ]
    }
  ]
};

const exampleSchemaHobbyRefLookupResponseEnglish = {
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

const exampleSchemaHobbyRefLookupResponseGerman = {
  "type": "string",
  "enumSource": [
    {
      "value": "{{item.value}}",
      "title": "{{item.title}}",
      "source": [
        {"value": "53323990-f4c8-4a25-8d83-a9313a403331", "title": "Kochen"},
        {"value": "3562eb73-a2be-ed86-26bd-28f18956c5b3", "title": "Tanzen"},
        {"value": "607f1626-8766-43d6-9931-bdde327e0cf1", "title": "Filmen"},
        {
          "value": "750b209c-cce5-4dc7-a4fa-6c76019ba73f",
          "title": "Gartenarbeit"
        },
        {"value": "98b21842-e696-401a-bb6e-b0afdad6ed24", "title": "Musik"},
        {"value": "e9287e38-5e14-45ed-a026-3e37295c7828", "title": "Malen"},
        {"value": "ba337609-a6af-875d-1282-b202be8c55ba", "title": "Lesen"},
        {"value": "a248b9d7-fdfd-4bc8-bab0-73a11443bb0e", "title": "Sport"},
        {"value": "50caf221-2ac9-4dda-aa7d-e8f9238ba86c", "title": "Reisen"},
        {"value": "ddcbe404-f7e7-494c-b0de-e76689cff554", "title": "Schreiben"}
      ]
    }
  ]
};

const exampleSchemaHobbyRefLookupResponse = {
  'en': exampleSchemaHobbyRefLookupResponseEnglish,
  'de': exampleSchemaHobbyRefLookupResponseGerman,
};

const availableLocales = {
  'en': 'English',
  'de': 'Deutsch',
};
