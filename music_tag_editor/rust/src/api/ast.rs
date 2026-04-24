use pest::Parser;
use pest_derive::Parser;

#[derive(Parser)]
#[grammar = "api/grammar.pest"]
pub struct RuleParser;

#[derive(Debug, Clone)]
enum Expr {
    Literal(String),
    Placeholder(String),
    Binary {
        left: Box<Expr>,
        op: String,
        right: Box<Expr>,
    },
    If {
        cond: Box<Expr>,
        then_branch: Box<Expr>,
        else_branch: Box<Expr>,
    },
    FunctionCall {
        name: String,
        arg: Box<Expr>,
    },
}

/// Converte uma string de regra em uma AST real.
pub fn parse_to_ast(input: String) -> Result<Expr, String> {
    let mut pairs = RuleParser::parse(Rule::expression, &input).map_err(|e| e.to_string())?;

    fn parse_pair(pair: pest::iterators::Pair<Rule>) -> Expr {
        match pair.as_rule() {
            Rule::expression => parse_pair(pair.into_inner().next().unwrap()),
            Rule::primary => parse_pair(pair.into_inner().next().unwrap()),
            Rule::placeholder => {
                let id = pair.into_inner().next().unwrap().as_str();
                Expr::Placeholder(id.to_string())
            }
            Rule::function_call => {
                let mut inner = pair.into_inner();
                let name = inner.next().unwrap().as_str().to_string();
                let arg = parse_pair(inner.next().unwrap());
                Expr::FunctionCall {
                    name,
                    arg: Box::new(arg),
                }
            }
            Rule::string_literal => {
                let s = pair.as_str();
                Expr::Literal(s[1..s.len() - 1].to_string())
            }
            Rule::binary_expr => {
                let mut inner = pair.into_inner();
                let left = parse_pair(inner.next().unwrap());
                let op = inner.next().unwrap().as_str().to_string();
                let right = parse_pair(inner.next().unwrap());
                Expr::Binary {
                    left: Box::new(left),
                    op,
                    right: Box::new(right),
                }
            }
            Rule::if_expr => {
                let mut inner = pair.into_inner();
                let cond = parse_pair(inner.next().unwrap());
                let then = parse_pair(inner.next().unwrap());
                let els = parse_pair(inner.next().unwrap());
                Expr::If {
                    cond: Box::new(cond),
                    then_branch: Box::new(then),
                    else_branch: Box::new(els),
                }
            }
            _ => Expr::Literal(pair.as_str().to_string()),
        }
    }

    Ok(parse_pair(pairs.next().unwrap()))
}

/// Avalia a AST contra metadados.
pub fn evaluate_ast(expr: Expr, metadata: crate::api::metadata::AudioMetadata) -> String {
    match expr {
        Expr::Literal(s) => s,
        Expr::Placeholder(p) => match p.as_str() {
            "title" => metadata.title.unwrap_or_default(),
            "artist" => metadata.artist.unwrap_or_default(),
            "album" => metadata.album.unwrap_or_default(),
            "genre" => metadata.genre.unwrap_or_default(),
            "year" => metadata.year.map(|y| y.to_string()).unwrap_or_default(),
            _ => String::new(),
        },
        Expr::Binary { left, op, right } => {
            let l = evaluate_ast(*left, metadata.clone());
            let r = evaluate_ast(*right, metadata);
            match op.as_str() {
                "+" => format!("{}{}", l, r),
                "==" => {
                    if l == r {
                        "true".to_string()
                    } else {
                        "false".to_string()
                    }
                }
                "!=" => {
                    if l != r {
                        "true".to_string()
                    } else {
                        "false".to_string()
                    }
                }
                _ => String::new(),
            }
        }
        Expr::If {
            cond,
            then_branch,
            else_branch,
        } => {
            let c = evaluate_ast(*cond, metadata.clone());
            if c == "true" {
                evaluate_ast(*then_branch, metadata)
            } else {
                evaluate_ast(*else_branch, metadata)
            }
        }
        Expr::FunctionCall { name, arg } => {
            let val = evaluate_ast(*arg, metadata);
            match name.as_str() {
                "clean" => crate::api::cleanup::clean_tag(val),
                "upper" => val.to_uppercase(),
                "lower" => val.to_lowercase(),
                _ => val,
            }
        }
    }
}

/// FUNÇÃO PRINCIPAL: Avalia uma regra de texto diretamente.
/// Esta função é o que o Flutter chama, evitando a necessidade de tipos complexos no Dart.
pub fn evaluate_rule(rule: String, metadata: crate::api::metadata::AudioMetadata) -> String {
    match parse_to_ast(rule) {
        Ok(ast) => evaluate_ast(ast, metadata),
        Err(e) => format!("Erro na regra: {}", e),
    }
}
