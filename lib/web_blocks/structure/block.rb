require 'web_blocks/framework'
require 'web_blocks/structure/tree/node'
require 'web_blocks/structure/block'
require 'web_blocks/structure/scss_file'
require 'web_blocks/structure/js_file'
require 'web_blocks/structure/attribute/dependency'
require 'web_blocks/structure/attribute/loose_dependency'
require 'web_blocks/structure/attribute/reverse_dependency'
require 'web_blocks/structure/attribute/reverse_loose_dependency'

module WebBlocks
  module Structure
    class Block < ::WebBlocks::Structure::Tree::Node

      include WebBlocks::Framework
      include WebBlocks::Structure::Attribute::Dependency
      include WebBlocks::Structure::Attribute::LooseDependency
      include WebBlocks::Structure::Attribute::ReverseDependency
      include WebBlocks::Structure::Attribute::ReverseLooseDependency

      set :required, false

      def resolved_path
        path = attributes.has_key?(:path) ? attributes[:path] : ''
        if attributes.has_key? :base_path
          Pathname.new(attributes[:base_path]) + path
        elsif parent
          parent.resolved_path + path
        else
          Pathname.new(path)
        end
      end

      def block name, attributes = {}, &block
        child_eval ::WebBlocks::Structure::Block, name, attributes, block
      end

      def scss_file name, attributes = {}, &block
        child_eval ::WebBlocks::Structure::ScssFile, name, attributes, block
      end

      def js_file name, attributes = {}, &block
        child_eval ::WebBlocks::Structure::JsFile, name, attributes, block
      end

      def files
        computed = []
        children.each do |name,object|
          if object.is_a? Block
            computed = computed + object.files
          elsif object.is_a? RawFile
            computed << object
          end
        end
        computed
      end

      def select_leaf_nodes branch_select_proc, leaf_select_proc
        leaf_nodes = []
        nodes = [self]
        while nodes.length > 0
          node = nodes.pop
          if node.respond_to? :children
            nodes |= node.children.values.select(&branch_select_proc)
          elsif leaf_select_proc.call(node)
            leaf_nodes << node
          end
        end
        leaf_nodes
      end

      def required_files
        select_leaf_nodes Proc.new(){ |node| node.get(:required) }, Proc.new(){ |node| node.is_a? RawFile }
      end

      private

      def child_add_or_update klass, name, attributes = {}
        unless has_child? name
          add_child klass.new(name, attributes)
        else
          attributes.each { |key, value| children[name].set key, value }
        end
        children[name]
      end

      def child_eval klass, name, attributes = {}, block
        child = child_add_or_update klass, name, attributes
        child.instance_exec children[name], &block if block
        child
      end

    end
  end
end