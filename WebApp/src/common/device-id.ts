export default function deviceId() {
  const deviceId = localStorage.getItem('deviceId')

  if (deviceId) {
    return deviceId

  } else {
    const deviceId = crypto.randomUUID()
    localStorage.setItem('deviceId', deviceId)
    return deviceId
  }
}