grammar asttypgen;

ID: ('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;
PERIOD: '.';
KW_PACKAGE: '@package';
KW_TOKEN_VOCAB: '@tokenVocab';
KW_TOKEN_TEXT: '@tokenText';
KW_PARSER_CLASS: '@parserClass';
KW_BASENODE_CODE: '@baseNodeCode';
KW_NODE_CODE: '@nodeCode';
KW_UNPARSER_BEFORE_CODE: '@unparserBeforeCode';
KW_UNPARSER_AFTER_CODE: '@unparserAfterCode';
KW_PARSER_BEFORE_CODE: '@parserBeforeCode';
KW_PARSER_AFTER_CODE: '@parserAfterCode';
KW_ANY: '@any';
COLON: ':';
SEMICOLON: ';';
SLASH: '/';
QUESTION: '?';
PLUS: '+';
ASTERISK: '*';
EQ: '=';
BRACKET_L: '[';
BRACKET_R: ']';
CURLY_L: '{';
CURLY_R: '}';
ARROW_R: '=>';
STRING
    @init { StringBuilder v = new StringBuilder(); }
    :
        '"'
        (
          options{greedy=false;}:
          c=~'\\' { v.append((char)$c); }
          | '\\\\' { v.append("\\"); }
          | '\\"' { v.append("\""); }
        )* '"'
        { setText(v.toString()); };
WS  :   ( ' '
        | '\t'
        | '\r'
        | '\n'
        ) {$channel=HIDDEN;};

COMMENT
  : '//' ~( '\r' | '\n' )* {$channel=HIDDEN;}
  | '/*' (options{greedy=false;}: .)* '*/' {$channel=HIDDEN;}
  ;

astSpec returns [AstNodes.AstSpec spec]:
  { $spec = new AstNodes.AstSpec(); }
  packageNameDef[$spec]
  tokenVocabName[$spec]
  parserClassName[$spec]
  parserBaseNodeCode[$spec]?
  parserNodeCode[$spec]?
  unparserBeforeCode[$spec]?
  unparserAfterCode[$spec]?
  parserBeforeCode[$spec]?
  parserAfterCode[$spec]?
  (r=ruleSpec { $spec.rules.add(r); })* EOF;
  
packageNameDef[AstNodes.AstSpec spec]:
  KW_PACKAGE r=ID { $spec.packageName.add($r.text); } (PERIOD r=ID { $spec.packageName.add($r.text); })*;

tokenVocabName[AstNodes.AstSpec spec]:
  KW_TOKEN_VOCAB r=ID { $spec.tokenVocabName.add($r.text); } (PERIOD r=ID { $spec.tokenVocabName.add($r.text); })*;
  
parserClassName[AstNodes.AstSpec spec]:
  KW_PARSER_CLASS r=ID { $spec.parserClassName = $r.text; };
  
parserBaseNodeCode[AstNodes.AstSpec spec]:
  KW_BASENODE_CODE s=STRING { $spec.baseNodeCode = $s.text; };
  
parserNodeCode[AstNodes.AstSpec spec]:
  KW_NODE_CODE s=STRING { $spec.nodeCode = $s.text; };
  
unparserBeforeCode[AstNodes.AstSpec spec]:
  KW_UNPARSER_BEFORE_CODE s=STRING { $spec.unparserBeforeCode = $s.text; };
  
unparserAfterCode[AstNodes.AstSpec spec]:
  KW_UNPARSER_AFTER_CODE s=STRING { $spec.unparserAfterCode = $s.text; };
  
parserBeforeCode[AstNodes.AstSpec spec]:
  KW_PARSER_BEFORE_CODE s=STRING { $spec.parserBeforeCode = $s.text; };
  
parserAfterCode[AstNodes.AstSpec spec]:
  KW_PARSER_AFTER_CODE s=STRING { $spec.parserAfterCode = $s.text; };

ruleSpec returns [AstNodes.RuleSpec result]:
  r1=ruleWithoutAlternatives { $result = $r1.result; }
  | r2=ruleWithAlternatives { $result = $r2.result; };

ruleWithoutAlternatives returns [AstNodes.RuleWithoutAlts result]:
  ID COLON ruleBody SEMICOLON
  {
    $result = new AstNodes.RuleWithoutAlts();
    $result.name = $ID.text;
    $result.body = $ruleBody.result;
  };
  
ruleWithAlternatives returns [AstNodes.RuleWithAlts result]:
  ruleName=ID
  {
    $result = new AstNodes.RuleWithAlts();
    $result.name = $ruleName.text;
  }
  ARROW_R
  (
    altName=ID
    { $result.alternatives.add($altName.text); }
  )+
  SEMICOLON;
  
ruleBody returns [AstNodes.RuleBody result]:
  ID
  {
    $result = new AstNodes.RuleBody();
    $result.rootType = $ID.text;
  }
  (
    r=ruleItem
    { $result.items.add($r.result); }
  )*;

ruleItem returns [AstNodes.RuleItem result]:
  (propSpec EQ)? propMatchSpec
  {
    $result = new AstNodes.RuleItem();
    $result.propMatchSpec = $propMatchSpec.result;
    if ($propSpec.result != null) {
      $result.propSpec = $propSpec.result;
    } else {
      $result.propSpec = $result.propMatchSpec.createDefaultPropSpec();
    }
  };
  
propSpec returns [AstNodes.PropSpec result]:
{ $result = new AstNodes.PropSpec(); }
  CURLY_L
  (
    QUESTION { $result.isQuestion = true; }
    | BRACKET_L BRACKET_R { $result.isArray = true; }
    |
  )
  ID CURLY_R
{ $result.name = $ID.text; };

propMatchSpec returns [AstNodes.PropMatchSpec result]:
  KW_TOKEN_TEXT
  {
    $result = new AstNodes.PropMatchSpec();
    $result.isTokenText = true;
  }
  |
  (id=ID|any=KW_ANY)
  {
    $result = new AstNodes.PropMatchSpec();
    $result.name = $id != null ? $id.text : null;
    $result.isAny = $any != null;
  }
  (
    QUESTION { $result.isQuestion = true; }
    | ASTERISK { $result.isAsterisk = true; }
    | PLUS { $result.isPlus = true; }
    |
  );