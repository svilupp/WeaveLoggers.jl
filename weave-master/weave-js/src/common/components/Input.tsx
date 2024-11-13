import * as React from 'react';
import {Input as SemanticInput, InputProps} from 'semantic-ui-react';

// Don't use this if it isn't necessary.
// When the value is updated asynchronously in the onChange callback,
// (e.g. as part of a redux action for views), the input box briefly gets its
// value reset to the saved state, and then immediately to the correct value,
// which forces the cursor position to the end.
// This wrapper passes the value as the defaultValue, which will make it have
// the correct value on mount, but could go out of sync if the source value can
// be changed in any way other than modifying this input.
const Input = (props: InputProps) => {
  const {value, ...rest} = props;
  return <SemanticInput {...rest} defaultValue={value} />;
};

export default Input;
