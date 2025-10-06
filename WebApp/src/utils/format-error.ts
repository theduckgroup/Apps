import { AxiosError } from "axios"

/// Formats Axios error.
export default function formatError(error: Error): string {
  if (!(error instanceof AxiosError)) {
    console.error(`Not an Error: ${error}`)
    return `Not an Error: ${JSON.stringify(error)}`
  }

  // Example Axios error:
  /*
  {
    code: "ERR_BAD_REQUEST" // ERR_BAD_REQUEST for all status code (400, 401 etc)
    config: ...
    message: "Request failed with status code 400"
    name : "AxiosError"
    request : XMLHttpRequest { ... }
    response : {
      data: { ... }, 
      status: 400, 
      statusText: 'Bad Request', 
      headers: AxiosHeaders, 
      config: ...
    }
    status: 400
    stack: "AxiosError: Request failed with status code 400 at ..."
  }
  */

  // Errors sent by our backends always include message and stack in response data (due to express-error-response middleware)
  // e.g., { message: ..., stack: ...}

  const response = error.response
  const data = response?.data

  console.info(error)

  if (!(data && typeof data == 'object' && 'message' in data && typeof data.message == 'string')) {
    console.error(`Error without data or data.message: ${error}`)
    return error.message // Error.message
  }
  
  // To show stack: data.stack
  return data.message
}