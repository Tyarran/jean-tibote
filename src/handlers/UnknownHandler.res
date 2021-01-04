let responses = [
  `hum... Je suis trop jeune pour comprendre cette requête. Désolé`,
  `Je ne comprends pas, désolé`,
  `Ceci n'est pas dans mes compétences`,
  `Je n'ai pas compris`,
  `Je n'ai pas compris :thinking_face:`,
  `Je ne sais pas faire ça`,
  `heu ?`,
  `:thinking_face:`,
]

let isUnknown = (message: Message.message) => message._type === Message.Type.Mention

let handle = _ => Utils.random(responses)
