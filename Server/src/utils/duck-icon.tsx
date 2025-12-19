export const DuckIcon = ({ style, ...rest }: React.ComponentProps<'div'>) => {
  const stroke = '#286090'
  const strokeWidth = 4.5

  const styles: Record<string, React.CSSProperties> = {
    container: {
      width: '19px',
      height: '24px',
      marginRight: '6px'
    }
  }

  return (
    <div style={{...styles.container, ...style}} {...rest}>
      {/* <svg viewBox="0 0 79 100" fill="none" xmlns="http://www.w3.org/2000/svg">
        <g clipPath="url(#clip0_2001_2)">
          <path d="M67 53.2C67.8 91 46.7 97.2 30.8 97.3C18.5 97.4 4.79998 88.1 3.79998 72.1C2.99998 58.5 13.8 50 27.6 42.3C40.2 35.3 50.9 30.1 51.6 19C52 11 44 1.90002 34.1 2.00002C23.7 2.10002 16.2 11.2 16.6 18.9C16.9 26.1 18.3 28.8 29.7 41.8C49.5 64 76.9 97.8 76.9 97.8" stroke={stroke} stroke-width={strokeWidth} stroke-miterlimit="10" stroke-linejoin="round" />
          <path d="M27.9 10.7C29 10.7 29.9 12.2 29.9 14.1C29.9 16 29 17.5 27.9 17.5C26.8 17.5 25.9 16 25.9 14.1C25.8 12.2 26.7 10.7 27.9 10.7Z" stroke={stroke} strokeWidth={strokeWidth} strokeMiterlimit="10" strokeLinecap="round" strokeLinejoin="round" />
          <path d="M16.5 16L2 22.6L18.1 27.4" stroke={stroke} strokeWidth={strokeWidth} strokeMiterlimit="10" strokeLinecap="round" strokeLinejoin="round" />
        </g>
        <defs>
          <clipPath id="clip0_2001_2">
            <rect width="78.4" height="99.2" fill="white" />
          </clipPath>
        </defs>
      </svg> */}
      <svg viewBox="0 -4 40 56" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M8.39796 8.198L1 11.5911L9.21429 14.0589" stroke={stroke} strokeWidth={strokeWidth} strokeMiterlimit="10" strokeLinecap="round" strokeLinejoin="round" />
        <path d="M14.2143 5.47321C14.7755 5.47321 15.2347 6.24438 15.2347 7.22119C15.2347 8.198 14.7755 8.96917 14.2143 8.96917C13.6531 8.96917 13.1939 8.198 13.1939 7.22119C13.1429 6.24438 13.602 5.47321 14.2143 5.47321Z" stroke={stroke} strokeWidth={2} strokeMiterlimit="10" strokeLinecap="round" strokeLinejoin="round" />
        <path d="M34.1633 27.323C34.5714 46.7565 23.8061 49.944 15.6939 49.9954C9.41836 50.0468 2.42856 45.2655 1.91836 37.0397C1.5102 30.0478 7.0204 25.6778 14.0612 21.7192C20.4898 18.1204 25.949 15.447 26.3061 9.74034C26.5102 5.62744 22.4286 0.949009 17.3775 1.00042C12.0714 1.05183 8.24489 5.73026 8.44897 9.68893C8.60203 13.3905 9.31632 14.7786 15.1326 21.4621C25.2347 32.8754 39.2143 50.2524 39.2143 50.2524" stroke={stroke} strokeWidth={strokeWidth} strokeMiterlimit="10" strokeLinejoin="round" />
      </svg>
    </div>
  )
}