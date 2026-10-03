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

///|
pub extend DiagramKind with @debug.Debug::{to_repr}

///|
pub extend DiagramKind with Eq::{not_equal, equal}

///|
pub extend ParseDiagnostic with @debug.Debug::{to_repr}

///|
pub extend ParseDiagnostic with Eq::{not_equal, equal}

///|
pub extend Direction with @debug.Debug::{to_repr}

///|
pub extend Direction with Eq::{not_equal, equal}

///|
pub extend NodeShape with @debug.Debug::{to_repr}

///|
pub extend NodeShape with Eq::{not_equal, equal}

///|
pub extend GraphNode with @debug.Debug::{to_repr}

///|
pub extend GraphNode with Eq::{not_equal, equal}

///|
pub extend GraphEdge with @debug.Debug::{to_repr}

///|
pub extend GraphEdge with Eq::{not_equal, equal}

///|
pub extend GraphSubgraph with @debug.Debug::{to_repr}

///|
pub extend GraphSubgraph with Eq::{not_equal, equal}

///|
pub extend GraphDiagram with @debug.Debug::{to_repr}

///|
pub extend GraphDiagram with Eq::{not_equal, equal}

///|
pub extend ActorKind with @debug.Debug::{to_repr}

///|
pub extend ActorKind with Eq::{not_equal, equal}

///|
pub extend SequenceActor with @debug.Debug::{to_repr}

///|
pub extend SequenceActor with Eq::{not_equal, equal}

///|
pub extend SequenceMessage with @debug.Debug::{to_repr}

///|
pub extend SequenceMessage with Eq::{not_equal, equal}

///|
pub extend SequenceEvent with @debug.Debug::{to_repr}

///|
pub extend SequenceEvent with Eq::{not_equal, equal}

///|
pub extend SequenceDiagram with @debug.Debug::{to_repr}

///|
pub extend SequenceDiagram with Eq::{not_equal, equal}

///|
pub extend TimelineItem with @debug.Debug::{to_repr}

///|
pub extend TimelineItem with Eq::{not_equal, equal}

///|
pub extend TimelineDiagram with @debug.Debug::{to_repr}

///|
pub extend TimelineDiagram with Eq::{not_equal, equal}

///|
pub extend OutlineKind with @debug.Debug::{to_repr}

///|
pub extend OutlineKind with Eq::{not_equal, equal}

///|
pub extend OutlineItem with @debug.Debug::{to_repr}

///|
pub extend OutlineItem with Eq::{not_equal, equal}

///|
pub extend OutlineDiagram with @debug.Debug::{to_repr}

///|
pub extend OutlineDiagram with Eq::{not_equal, equal}

///|
pub extend GitGraphEvent with @debug.Debug::{to_repr}

///|
pub extend GitGraphEvent with Eq::{not_equal, equal}

///|
pub extend GitGraphDiagram with @debug.Debug::{to_repr}

///|
pub extend GitGraphDiagram with Eq::{not_equal, equal}

///|
pub extend GanttTask with @debug.Debug::{to_repr}

///|
pub extend GanttTask with Eq::{not_equal, equal}

///|
pub extend GanttDiagram with @debug.Debug::{to_repr}

///|
pub extend GanttDiagram with Eq::{not_equal, equal}

///|
pub extend MermaidDiagram with @debug.Debug::{to_repr}

///|
pub extend MermaidDiagram with Eq::{not_equal, equal}

///|
pub extend Point with @debug.Debug::{to_repr}

///|
pub extend Point with Eq::{not_equal, equal}

///|
pub extend LayoutBox with @debug.Debug::{to_repr}

///|
pub extend LayoutBox with Eq::{not_equal, equal}

///|
pub extend PositionedNode with @debug.Debug::{to_repr}

///|
pub extend PositionedNode with Eq::{not_equal, equal}

///|
pub extend PositionedEdge with @debug.Debug::{to_repr}

///|
pub extend PositionedEdge with Eq::{not_equal, equal}

///|
pub extend PositionedGraph with @debug.Debug::{to_repr}

///|
pub extend PositionedGraph with Eq::{not_equal, equal}

///|
pub extend PositionedActor with @debug.Debug::{to_repr}

///|
pub extend PositionedActor with Eq::{not_equal, equal}

///|
pub extend PositionedMessage with @debug.Debug::{to_repr}

///|
pub extend PositionedMessage with Eq::{not_equal, equal}

///|
pub extend PositionedSequence with @debug.Debug::{to_repr}

///|
pub extend PositionedSequence with Eq::{not_equal, equal}
