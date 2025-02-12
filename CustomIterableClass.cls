public class CustomIterableClass implements Iterator<Id>, Iterable<Id> {
    private List<Id> scope;
    private Integer position;

    public CustomIterableClass(Set<Id> theScope) {
        scope = new List<Id>(theScope);
        position = 0;
    }

    public boolean hasNext() {
        return position < scope.size();
    }

    public Id next() {
        return scope.get(position++);
    }

    public void remove() {
        throw new UnsupportedOperationException();
    }

    public Iterator<Id> iterator() {
        return this;
    }
}
