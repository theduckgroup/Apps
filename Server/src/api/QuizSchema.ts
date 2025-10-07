import Ajv, { Schema } from 'ajv/dist/jtd.js'

const schema = { // Can't annotate `Schema` type, will break type validation
  definitions: {
    Quiz: {
      properties: {
        id: { type: 'string' },
        name: { type: 'string' },
        items: { elements: { ref: 'Item' } },
        sections: { elements: { ref: 'Section' } }
      }
    },
    Item: {
      discriminator: 'kind',
      mapping: {
        // Note: can't use ref in mapping, must define properties directly
        listItem: {
          properties: {
            id: { type: 'string' },
            data: {
              properties: {
                prompt: { type: 'string' },
                items: { elements: { ref: 'Item' } }
              }
            }
          }
        },
        selectedResponseItem: {
          properties: {
            id: { type: 'string' },
            data: {
              properties: {
                prompt: { type: 'string' },
                options: {
                  elements: {
                    properties: {
                      id: { type: 'string' },
                      value: { type: 'string' }
                    }
                  }
                }
              }
            }
          }
        },
        textInputItem: {
          properties: {
            id: { type: 'string' },
            data: {
              properties: {
                prompt: { type: 'string' }
              }
            }
          }
        }
      }
    },
    Section: {
      properties: {
        id: { type: 'string' },
        name: { type: 'string' },
        rows: {
          elements: {
            properties: {
              itemId: { type: 'string' }
            }
          }
        }
      }
    }
  },
  ref: 'Quiz'
} as const

const validateQuiz = new Ajv().compile(schema)

export { validateQuiz }