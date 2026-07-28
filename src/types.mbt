///|
pub enum DiagramKind {
  Flowchart
  State
  Class
  Er
} derive(Debug, Eq)

///|
pub struct ParseDiagnostic {
  line : Int
  column : Int
  message : String
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
  Diamond
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
pub struct GraphSubgraph {
  id : String
  label : String
  node_ids : Array[String]
  depth : Int
} derive(Debug, Eq)

///|
pub struct GraphDiagram {
  kind : DiagramKind
  direction : Direction
  nodes : Array[GraphNode]
  edges : Array[GraphEdge]
  subgraphs : Array[GraphSubgraph]
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
pub enum SequenceEvent {
  Message(SequenceMessage)
  Note(String, String)
  Activate(String)
  Deactivate(String)
  BlockStart(String, String)
  BlockElse(String)
  BlockAnd(String)
  BlockEnd
} derive(Debug, Eq)

///|
pub struct SequenceDiagram {
  actors : Array[SequenceActor]
  messages : Array[SequenceMessage]
  events : Array[SequenceEvent]
  autonumber : Bool
  has_extended_syntax : Bool
} derive(Debug, Eq)

///|
pub struct TimelineItem {
  period : String
  events : Array[String]
} derive(Debug, Eq)

///|
pub struct TimelineDiagram {
  title : String?
  items : Array[TimelineItem]
} derive(Debug, Eq)

///|
pub enum OutlineKind {
  Mindmap
  Journey
  Pie
} derive(Debug, Eq)

///|
pub struct OutlineItem {
  depth : Int
  label : String
} derive(Debug, Eq)

///|
pub struct OutlineDiagram {
  kind : OutlineKind
  title : String?
  items : Array[OutlineItem]
} derive(Debug, Eq)

///|
pub enum GitGraphEvent {
  Commit(String, String)
  Branch(String)
  Checkout(String)
  Merge(String)
} derive(Debug, Eq)

///|
pub struct GitGraphDiagram {
  events : Array[GitGraphEvent]
} derive(Debug, Eq)

///|
pub struct GanttTask {
  section : String?
  name : String
  start : String
  duration : String
  status : String?
} derive(Debug, Eq)

///|
pub struct GanttDiagram {
  title : String?
  date_format : String?
  tasks : Array[GanttTask]
} derive(Debug, Eq)

///|
pub enum MermaidDiagram {
  Graph(GraphDiagram)
  Sequence(SequenceDiagram)
  Timeline(TimelineDiagram)
  GitGraph(GitGraphDiagram)
  Gantt(GanttDiagram)
  Outline(OutlineDiagram)
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
