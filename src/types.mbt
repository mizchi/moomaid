///|
pub enum DiagramKind {
  Flowchart
  State
  Class
  Er
} derive(Debug, Eq)

///|
pub enum Direction {
  TD
  LR
  BT
  RL
} derive(Debug, Eq)

///|
pub enum NodeShape {
  Rect
  Rounded
  Circle
  StateStart
  StateEnd
} derive(Debug, Eq)

///|
pub struct GraphNode {
  id : String
  label : String
  shape : NodeShape
  sections : Array[Array[String]]
} derive(Debug, Eq)

///|
pub struct GraphEdge {
  from : String
  to : String
  label : String?
} derive(Debug, Eq)

///|
pub struct GraphDiagram {
  kind : DiagramKind
  direction : Direction
  nodes : Array[GraphNode]
  edges : Array[GraphEdge]
} derive(Debug, Eq)

///|
pub enum ActorKind {
  Participant
  Actor
} derive(Debug, Eq)

///|
pub struct SequenceActor {
  id : String
  label : String
  kind : ActorKind
} derive(Debug, Eq)

///|
pub struct SequenceMessage {
  from : String
  to : String
  text : String
  dashed : Bool
} derive(Debug, Eq)

///|
pub struct SequenceDiagram {
  actors : Array[SequenceActor]
  messages : Array[SequenceMessage]
} derive(Debug, Eq)

///|
pub enum MermaidDiagram {
  Graph(GraphDiagram)
  Sequence(SequenceDiagram)
} derive(Debug, Eq)

///|
struct Point {
  x : Int
  y : Int
} derive(Debug, Eq)

///|
struct LayoutBox {
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Debug, Eq)

///|
struct PositionedNode {
  node : GraphNode
  box : LayoutBox
} derive(Debug, Eq)

///|
struct PositionedEdge {
  edge : GraphEdge
  start : Point
  end : Point
} derive(Debug, Eq)

///|
struct PositionedGraph {
  nodes : Array[PositionedNode]
  edges : Array[PositionedEdge]
  width : Int
  height : Int
  direction : Direction
  kind : DiagramKind
} derive(Debug, Eq)

///|
struct PositionedActor {
  actor : SequenceActor
  box : LayoutBox
} derive(Debug, Eq)

///|
struct PositionedMessage {
  message : SequenceMessage
  start : Point
  end : Point
  y : Int
} derive(Debug, Eq)

///|
struct PositionedSequence {
  actors : Array[PositionedActor]
  messages : Array[PositionedMessage]
  width : Int
  height : Int
} derive(Debug, Eq)
