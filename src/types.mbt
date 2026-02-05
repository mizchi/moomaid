///|
pub enum DiagramKind {
  Flowchart
  State
  Class
  Er
} derive(Show, Eq)

///|
pub enum Direction {
  TD
  LR
  BT
  RL
} derive(Show, Eq)

///|
pub enum NodeShape {
  Rect
  Rounded
  Circle
  StateStart
  StateEnd
} derive(Show, Eq)

///|
pub struct GraphNode {
  id : String
  label : String
  shape : NodeShape
  sections : Array[Array[String]]
} derive(Show, Eq)

///|
pub struct GraphEdge {
  from : String
  to : String
  label : String?
} derive(Show, Eq)

///|
pub struct GraphDiagram {
  kind : DiagramKind
  direction : Direction
  nodes : Array[GraphNode]
  edges : Array[GraphEdge]
} derive(Show, Eq)

///|
pub enum ActorKind {
  Participant
  Actor
} derive(Show, Eq)

///|
pub struct SequenceActor {
  id : String
  label : String
  kind : ActorKind
} derive(Show, Eq)

///|
pub struct SequenceMessage {
  from : String
  to : String
  text : String
  dashed : Bool
} derive(Show, Eq)

///|
pub struct SequenceDiagram {
  actors : Array[SequenceActor]
  messages : Array[SequenceMessage]
} derive(Show, Eq)

///|
pub enum MermaidDiagram {
  Graph(GraphDiagram)
  Sequence(SequenceDiagram)
} derive(Show, Eq)

///|
struct Point {
  x : Int
  y : Int
} derive(Show, Eq)

///|
struct LayoutBox {
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Show, Eq)

///|
struct PositionedNode {
  node : GraphNode
  box : LayoutBox
} derive(Show, Eq)

///|
struct PositionedEdge {
  edge : GraphEdge
  start : Point
  end : Point
} derive(Show, Eq)

///|
struct PositionedGraph {
  nodes : Array[PositionedNode]
  edges : Array[PositionedEdge]
  width : Int
  height : Int
  direction : Direction
  kind : DiagramKind
} derive(Show, Eq)

///|
struct PositionedActor {
  actor : SequenceActor
  box : LayoutBox
} derive(Show, Eq)

///|
struct PositionedMessage {
  message : SequenceMessage
  start : Point
  end : Point
  y : Int
} derive(Show, Eq)

///|
struct PositionedSequence {
  actors : Array[PositionedActor]
  messages : Array[PositionedMessage]
  width : Int
  height : Int
} derive(Show, Eq)
