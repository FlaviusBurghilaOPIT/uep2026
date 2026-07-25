import {
  FontAwesomeIcon,
  type FontAwesomeIconProps,
} from '@fortawesome/react-fontawesome'
import type { IconDefinition } from '@fortawesome/fontawesome-svg-core'

type IconProps = {
  icon: IconDefinition
  size?: FontAwesomeIconProps['size']
  /** Accessible name. Omit for decorative icons (the default). */
  label?: string
  style?: React.CSSProperties
}

export function Icon({ icon, size, label, style }: IconProps) {
  return (
    <FontAwesomeIcon
      icon={icon}
      size={size}
      style={style as FontAwesomeIconProps['style']}
      aria-hidden={label ? undefined : true}
      aria-label={label}
      role={label ? 'img' : undefined}
    />
  )
}
