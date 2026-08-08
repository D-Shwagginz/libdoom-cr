{% if flag?(:windows) %}
  WIN32 = true
{% elsif flag?(:macosx) %}
  APPLE = true
{% else %}
  LINUX = true
{% end %}

macro abs(x)
  (({{x}}) < 0 ? -({{x}}) : ({{x}}))
end
