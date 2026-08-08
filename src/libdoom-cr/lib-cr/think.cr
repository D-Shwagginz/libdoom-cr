alias ActionfV = Proc(Nil)
alias ActionfP1 = Proc(Void*, Nil)
alias ActionfP2 = Proc(Void*, Void*, Nil)

alias Actionf = ActionfP1 | ActionfV | ActionfP2

# Historically, "think_t" is yet another
#  function pointer to a routine to handle
#  an actor.
alias Think = Actionf

# Doubly linked list of actors.
struct Thinker
  property prev : Thinker*?
  property next : Thinker*?
  property function : Think?
end
