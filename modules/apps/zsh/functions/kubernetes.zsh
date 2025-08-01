function kubernetes_current_context() {
  local ctx
  ctx=$(which kubectl > /dev/null)
  local ret=$?
  if [[ $ret != 0 ]]; then
    echo ""
  else
    kubectl config current-context 2> /dev/null
  fi
}

kubernetes_custom_status() {
  local kc=$(kubernetes_current_context)
  if [ -n "$kc" ]; then
    echo "$ZSH_THEME_KUBERNETES_PROMPT_PREFIX$(kubernetes_current_context)$ZSH_THEME_KUBERNETES_PROMPT_SUFFIX"
  fi
}
